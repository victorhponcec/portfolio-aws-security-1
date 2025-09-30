resource "aws_accessanalyzer_analyzer" "external" {
  analyzer_name = "external"
  type          = "ACCOUNT"
}

resource "aws_accessanalyzer_analyzer" "unused" {
  analyzer_name = "unused"
  type          = "ACCOUNT_UNUSED_ACCESS"
}
