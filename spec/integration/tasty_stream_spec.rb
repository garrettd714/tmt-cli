RSpec.describe "`tmt tasty_stream` command", type: :cli do
  it "executes `tmt help tasty_stream` command successfully" do
    output = `tmt help tasty_stream`
    expected_output = <<-OUT
Usage:
  tmt tasty_stream

Options:
  -h, [--help], [--no-help]  # For tasty-refresh use only
      [--bid=N]              # bid from tastyworks
      [--ask=N]              # ask from tastyworks

Tasty streamer update for internal use only
    OUT

    expect(output).to include(expected_output)
  end
end
