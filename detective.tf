resource "aws_detective_graph" "detective_activation" {
  tags = {
    Name = "detective-graph"
  }
}