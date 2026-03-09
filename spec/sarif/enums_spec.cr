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
end
