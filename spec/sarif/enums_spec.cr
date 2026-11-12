require "../spec_helper"

describe "Sarif Enums" do
  describe Sarif::Level do
    it "serializes to JSON" do
      Sarif::Level::Warning.to_json.should eq(%("warning"))
      Sarif::Level::Error.to_json.should eq(%("error"))
      Sarif::Level::Note.to_json.should eq(%("note"))
      Sarif::Level::None.to_json.should eq(%("none"))
    end

    it "deserializes from JSON" do
      Sarif::Level.from_json(%("warning")).should eq(Sarif::Level::Warning)
      Sarif::Level.from_json(%("error")).should eq(Sarif::Level::Error)
      Sarif::Level.from_json(%("note")).should eq(Sarif::Level::Note)
      Sarif::Level.from_json(%("none")).should eq(Sarif::Level::None)
    end

    it "round-trips through JSON" do
      Sarif::Level.values.each do |val|
        json = val.to_json
        Sarif::Level.from_json(json).should eq(val)
      end
    end

    it "raises Sarif::Error for an unknown value via from_json (pull parser) in strict mode" do
      Sarif.with_strict_enums do
        expect_raises(Sarif::Error, /Unknown/) do
          Sarif::Level.from_json(JSON::PullParser.new(%("bogus")))
        end
      end
    end

    it "raises Sarif::Error for an unknown value via parse_sarif in strict mode" do
      Sarif.with_strict_enums do
        expect_raises(Sarif::Error, /Unknown/) do
          Sarif::Level.parse_sarif("bogus")
        end
      end
    end

    it "maps an unknown value to the Unknown sentinel by default (tolerant)" do
      Sarif::Level.parse_sarif("bogus").should eq(Sarif::Level::Unknown)
      Sarif::Level.from_json(JSON::PullParser.new(%("bogus"))).should eq(Sarif::Level::Unknown)
      Sarif::Level.new(JSON::PullParser.new(%("critical"))).should eq(Sarif::Level::Unknown)
    end

    it "round-trips the Unknown sentinel through JSON" do
      Sarif::Level::Unknown.to_json.should eq(%("unknown"))
      Sarif::Level.from_json(%("unknown")).should eq(Sarif::Level::Unknown)
    end
  end

  describe Sarif::ResultKind do
    it "serializes to JSON" do
      Sarif::ResultKind::Fail.to_json.should eq(%("fail"))
      Sarif::ResultKind::Pass.to_json.should eq(%("pass"))
      Sarif::ResultKind::NotApplicable.to_json.should eq(%("notApplicable"))
      Sarif::ResultKind::Open.to_json.should eq(%("open"))
      Sarif::ResultKind::Review.to_json.should eq(%("review"))
      Sarif::ResultKind::Informational.to_json.should eq(%("informational"))
    end

    it "round-trips through JSON" do
      Sarif::ResultKind.values.each do |val|
        json = val.to_json
        Sarif::ResultKind.from_json(json).should eq(val)
      end
    end
  end

  describe Sarif::BaselineState do
    it "round-trips through JSON" do
      Sarif::BaselineState.values.each do |val|
        Sarif::BaselineState.from_json(val.to_json).should eq(val)
      end
    end
  end

  describe Sarif::SuppressionKind do
    it "serializes correctly" do
      Sarif::SuppressionKind::InSource.to_json.should eq(%("inSource"))
      Sarif::SuppressionKind::External.to_json.should eq(%("external"))
    end
  end

  describe Sarif::SuppressionStatus do
    it "round-trips through JSON" do
      Sarif::SuppressionStatus.values.each do |val|
        Sarif::SuppressionStatus.from_json(val.to_json).should eq(val)
      end
    end
  end

  describe Sarif::Importance do
    it "round-trips through JSON" do
      Sarif::Importance.values.each do |val|
        Sarif::Importance.from_json(val.to_json).should eq(val)
      end
    end
  end

  describe Sarif::ArtifactRole do
    it "serializes to camelCase" do
      Sarif::ArtifactRole::AnalysisTarget.to_json.should eq(%("analysisTarget"))
      Sarif::ArtifactRole::ReferencedOnCommandLine.to_json.should eq(%("referencedOnCommandLine"))
    end

    it "round-trips through JSON" do
      Sarif::ArtifactRole.values.each do |val|
        Sarif::ArtifactRole.from_json(val.to_json).should eq(val)
      end
    end
  end

  describe Sarif::ColumnKind do
    it "serializes correctly" do
      Sarif::ColumnKind::Utf16CodeUnits.to_json.should eq(%("utf16CodeUnits"))
      Sarif::ColumnKind::UnicodeCodePoints.to_json.should eq(%("unicodeCodePoints"))
    end
  end

  describe Sarif::ToolComponentContent do
    it "round-trips through JSON" do
      Sarif::ToolComponentContent.values.each do |val|
        Sarif::ToolComponentContent.from_json(val.to_json).should eq(val)
      end
    end
  end

  describe "Sarif.strict_enums" do
    it "defaults to false (tolerant)" do
      Sarif.strict_enums.should be_false
    end

    it "is restored after with_strict_enums even when the block raises" do
      Sarif.strict_enums.should be_false
      expect_raises(Sarif::Error) do
        Sarif.with_strict_enums do
          Sarif.strict_enums.should be_true
          Sarif::Level.parse_sarif("nope")
        end
      end
      Sarif.strict_enums.should be_false
    end

    it "with_strict_enums is scoped to the calling fiber" do
      inside = Channel(Nil).new
      release = Channel(Nil).new
      spawn do
        Sarif.with_strict_enums do
          inside.send(nil)
          release.receive # parked inside the block, e.g. waiting on IO
        end
      end
      inside.receive
      begin
        Sarif.strict_enums.should be_false
        Sarif::Level.parse_sarif("nope").should eq(Sarif::Level::Unknown)
      ensure
        release.send(nil)
      end
    end

    it "with_strict_enums restores correctly when fibers interleave" do
      a_in = Channel(Nil).new
      b_in = Channel(Nil).new
      a_out = Channel(Nil).new
      b_out = Channel(Nil).new
      done = Channel(Bool).new
      spawn { Sarif.with_strict_enums { a_in.send(nil); a_out.receive } }
      spawn { Sarif.with_strict_enums { b_in.send(nil); b_out.receive; done.send(Sarif.strict_enums) } }
      a_in.receive
      b_in.receive
      a_out.send(nil) # A leaves first, while B is still inside its block
      b_out.send(nil)
      done.receive.should be_true
      Sarif.strict_enums.should be_false
    end
  end

  describe "tolerant full-document parsing" do
    doc = <<-JSON
      {
        "version": "2.1.0",
        "runs": [
          {
            "tool": {"driver": {"name": "MyTool"}},
            "results": [
              {
                "message": {"text": "x"},
                "level": "critical",
                "kind": "futureKind",
                "baselineState": "weird"
              }
            ]
          }
        ]
      }
      JSON

    it "does not raise on an unknown level/kind and yields a parseable log" do
      log = Sarif::SarifLog.from_json(doc)
      result = log.runs!.first.results.not_nil!.first
      result.level.should eq(Sarif::Level::Unknown)
      result.kind.should eq(Sarif::ResultKind::Unknown)
      result.baseline_state.should eq(Sarif::BaselineState::Unknown)
    end

    it "is reachable through Sarif.parse without raising" do
      log = Sarif.parse(doc)
      log.runs!.first.results.not_nil!.first.level.should eq(Sarif::Level::Unknown)
    end

    it "re-serializes the sentinel as \"unknown\" without crashing" do
      log = Sarif::SarifLog.from_json(doc)
      json = log.to_json
      json.should contain(%("level":"unknown"))
    end

    it "raises Sarif::Error in strict mode" do
      Sarif.with_strict_enums do
        expect_raises(Sarif::Error, /Unknown/) do
          Sarif::SarifLog.from_json(doc)
        end
      end
    end
  end
end
