require "rails_helper"
require "webmock/rspec"

RSpec.describe Restaurants::NearbySearch do
  # 1. A user who can actually search: without max_walking_minutes the radius
  #    would be 0 and the service would refuse to call Google at all.
  let(:user) do
    User.create!(email: "search@example.com", password: "password",
                 max_walking_minutes: 15)
  end

  let(:latitude)  { 48.8642 }
  let(:longitude) { 2.3814 }

  let(:endpoint) { "https://places.googleapis.com/v1/places:searchNearby" }

  # 2. One place per stubbed answer, built from the id so each batch can return
  #    a distinguishable restaurant.
  def place(id)
    {
      "id" => id,
      "displayName" => { "text" => "Chez #{id}" },
      "formattedAddress" => "#{id} rue de Paris",
      "location" => { "latitude" => latitude, "longitude" => longitude },
      "types" => ["restaurant"]
    }
  end

  def body_for(*ids)
    { "places" => ids.map { |id| place(id) } }.to_json
  end

  # 3. Tags are what end up in includedTypes, so the count here drives the
  #    number of requests the service is expected to make.
  def give_user_tags(count)
    tags = Array.new(count) do |i|
      Tag.create!(api_type: "type_#{i}_restaurant", frontend_type: "Type #{i}",
                  frontend_tag: "Cuisines du monde")
    end
    user.tags = tags
  end

  before do
    stub_const("ENV", ENV.to_h.merge("GOOGLE_PLACES_API_KEY" => "test-key"))
  end

  def search
    described_class.call(user: user, latitude: latitude, longitude: longitude)
  end

  describe "batching of includedTypes" do
    it "sends a single request when the user stays under Google's limit" do
      give_user_tags(50)
      stub_request(:post, endpoint).to_return(status: 200, body: body_for("a"))

      expect(search.map(&:google_place_id)).to eq(["a"])
      expect(a_request(:post, endpoint)).to have_been_made.once
    end

    it "splits the selection into slices of 50 rather than letting Google reject it" do
      # 1. 56 cuisines is what triggered the production 400: one slice of 50 and
      #    one of 6.
      give_user_tags(56)
      stub_request(:post, endpoint)
        .to_return({ status: 200, body: body_for("a", "b") },
                   { status: 200, body: body_for("c") })

      expect(search.map(&:google_place_id)).to match_array(%w[a b c])
      expect(a_request(:post, endpoint)).to have_been_made.twice
    end

    it "never sends more than 50 types in one request" do
      give_user_tags(120)
      stub_request(:post, endpoint).to_return(status: 200, body: body_for("a"))

      search

      expect(a_request(:post, endpoint).with { |req|
        JSON.parse(req.body)["includedTypes"].size <= 50
      }).to have_been_made.times(3)
    end

    it "deduplicates a restaurant returned by two slices" do
      give_user_tags(56)
      stub_request(:post, endpoint)
        .to_return({ status: 200, body: body_for("shared") },
                   { status: 200, body: body_for("shared") })

      expect(search.map(&:google_place_id)).to eq(["shared"])
    end

    it "falls back to plain restaurants when the user picked no cuisine" do
      stub_request(:post, endpoint).to_return(status: 200, body: body_for("a"))

      search

      expect(a_request(:post, endpoint).with { |req|
        JSON.parse(req.body)["includedTypes"] == ["restaurant"]
      }).to have_been_made.once
    end
  end

  describe "partial failures" do
    it "keeps the places of the slices that answered" do
      give_user_tags(56)
      stub_request(:post, endpoint)
        .to_return({ status: 200, body: body_for("a") },
                   { status: 400, body: '{"error":{"message":"boom"}}' })

      expect(search.map(&:google_place_id)).to eq(["a"])
    end

    it "returns nil so the caller shows the retry screen when every slice fails" do
      give_user_tags(56)
      stub_request(:post, endpoint).to_return(status: 400, body: '{"error":{"message":"boom"}}')

      expect(search).to be_nil
    end
  end

  describe "guards that avoid a pointless call" do
    it "refuses to search without a walking time, which would mean a radius of 0" do
      user.update!(max_walking_minutes: nil)

      expect(search).to be_nil
      expect(a_request(:post, endpoint)).not_to have_been_made
    end

    it "refuses coordinates that never made it out of the session" do
      expect(described_class.call(user: user, latitude: nil, longitude: nil)).to be_nil
      expect(a_request(:post, endpoint)).not_to have_been_made
    end
  end

  describe "places we cannot save" do
    it "skips a place without an address instead of losing the whole search" do
      # 1. Restaurant validates the presence of an address, so this one cannot
      #    be saved — the other must still come through.
      give_user_tags(3)
      places = { "places" => [place("ok"), place("broken").except("formattedAddress")] }
      stub_request(:post, endpoint).to_return(status: 200, body: places.to_json)

      expect(search.map(&:google_place_id)).to eq(["ok"])
    end
  end
end
