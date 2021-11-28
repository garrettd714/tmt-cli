RSpec.describe "`tmt tasty_refresh` command", type: :cli do
  it "executes `tmt help tasty_refresh` command successfully" do
    output = `tmt help tasty_refresh`
    expected_output = <<-OUT
Usage:
  tmt tasty_refresh

Options:
  -h, [--help], [--no-help]  # For tasty-refresh use only

Tasty streamer mark refresh on exit for internal use only
    OUT

    expect(output).to include(expected_output)
  end
end
