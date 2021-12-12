RSpec.describe "`tmt tasty_refresh` command", type: :cli do
  it "executes `tmt help tasty_refresh` command successfully" do
    output = `tmt help tasty_refresh`
    expected_output = <<-OUT
Usage:
  tmt tasty_refresh

Options:
  -h, [--help], [--no-help]  # For tasty-refresh use only

Tasty streamer mark refresher hook (for streamer use only)
    OUT

    expect(output).to include(expected_output)
  end
end
