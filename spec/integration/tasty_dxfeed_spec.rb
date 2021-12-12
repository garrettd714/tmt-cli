RSpec.describe "`tmt tasty_dxfeed` command", type: :cli do
  it "executes `tmt help tasty_dxfeed` command successfully" do
    output = `tmt help tasty_dxfeed`
    expected_output = <<-OUT
Usage:
  tmt tasty_dxfeed

Options:
  -h, [--help], [--no-help]  # For tasty-refresh use only

Tasty streamer dxfeed symbols hook (for streamer use only)
    OUT

    expect(output).to include(expected_output)
  end
end
