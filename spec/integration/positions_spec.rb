RSpec.describe "`tmt positions` command", type: :cli do
  it "executes `tmt help positions` command successfully" do
    output = `tmt help positions`
    expected_output = <<-OUT
Usage:
  tmt positions

Options:
  -h, [--help], [--no-help]        # Display table of open positions
  -r, [--refresh], [--no-refresh]  # Refresh the details of the stock/etf positions

List positions, -p [--list | -l]
    OUT

    expect(output).to include(expected_output)
  end
end
