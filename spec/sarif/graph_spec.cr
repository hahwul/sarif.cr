require "../spec_helper"

describe Sarif::Graph do
  it "creates with defaults" do
    graph = Sarif::Graph.new
    graph.nodes.should be_nil
    graph.edges.should be_nil
    graph.description.should be_nil
  end

  it "creates with nodes and edges" do
    graph = Sarif::Graph.new(
      description: Sarif::Message.new(text: "Call graph"),
      nodes: [
        Sarif::Node.new(id: "n1", label: Sarif::Message.new(text: "Entry")),
        Sarif::Node.new(id: "n2", label: Sarif::Message.new(text: "Exit")),
      ],
      edges: [
        Sarif::Edge.new(id: "e1", source_node_id: "n1", target_node_id: "n2"),
      ]
    )
    graph.nodes.not_nil!.size.should eq(2)
    graph.edges.not_nil!.size.should eq(1)
    graph.description.not_nil!.text.should eq("Call graph")
  end

  it "round-trips through JSON" do
    graph = Sarif::Graph.new(
      nodes: [Sarif::Node.new(id: "a"), Sarif::Node.new(id: "b")],
      edges: [Sarif::Edge.new(id: "e1", source_node_id: "a", target_node_id: "b")]
    )
    restored = Sarif::Graph.from_json(graph.to_json)
    restored.nodes.not_nil!.size.should eq(2)
    restored.edges.not_nil![0].source_node_id.should eq("a")
    restored.edges.not_nil![0].target_node_id.should eq("b")
  end
end

describe Sarif::Node do
  it "creates with id" do
    node = Sarif::Node.new(id: "node1")
    node.id.should eq("node1")
    node.label.should be_nil
    node.location.should be_nil
    node.children.should be_nil
  end

  it "supports label and location" do
    node = Sarif::Node.new(
      id: "n1",
      label: Sarif::Message.new(text: "function main"),
      location: Sarif::Location.new(
        physical_location: Sarif::PhysicalLocation.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "main.cr"),
          region: Sarif::Region.new(start_line: 1)
        )
      )
    )
    node.label.not_nil!.text.should eq("function main")
    node.location.not_nil!.physical_location.not_nil!.artifact_location.not_nil!.uri.should eq("main.cr")
  end

  it "supports nested children" do
    node = Sarif::Node.new(
      id: "parent",
      children: [
        Sarif::Node.new(id: "child1"),
        Sarif::Node.new(id: "child2"),
      ]
    )
    node.children.not_nil!.size.should eq(2)
    node.children.not_nil![0].id.should eq("child1")
  end

  it "round-trips through JSON" do
    node = Sarif::Node.new(
      id: "n1",
      label: Sarif::Message.new(text: "test"),
      children: [Sarif::Node.new(id: "c1")]
    )
    restored = Sarif::Node.from_json(node.to_json)
    restored.id.should eq("n1")
    restored.children.not_nil![0].id.should eq("c1")
  end
end

describe Sarif::Edge do
  it "creates with required fields" do
    edge = Sarif::Edge.new(id: "e1", source_node_id: "n1", target_node_id: "n2")
    edge.id.should eq("e1")
    edge.source_node_id.should eq("n1")
    edge.target_node_id.should eq("n2")
    edge.label.should be_nil
  end

  it "supports label" do
    edge = Sarif::Edge.new(
      id: "e1", source_node_id: "a", target_node_id: "b",
      label: Sarif::Message.new(text: "calls")
    )
    edge.label.not_nil!.text.should eq("calls")
  end

  it "serializes with camelCase keys" do
    edge = Sarif::Edge.new(id: "e1", source_node_id: "src", target_node_id: "tgt")
    json = edge.to_json
    parsed = JSON.parse(json)
    parsed["sourceNodeId"].as_s.should eq("src")
    parsed["targetNodeId"].as_s.should eq("tgt")
  end

  it "round-trips through JSON" do
    edge = Sarif::Edge.new(
      id: "e1", source_node_id: "a", target_node_id: "b",
      label: Sarif::Message.new(text: "flow")
    )
    restored = Sarif::Edge.from_json(edge.to_json)
    restored.id.should eq("e1")
    restored.source_node_id.should eq("a")
    restored.label.not_nil!.text.should eq("flow")
  end
end
