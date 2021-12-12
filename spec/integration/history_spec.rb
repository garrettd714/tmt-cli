RSpec.describe "`tmt history` command", type: :cli do
  it "executes `tmt help history` command successfully" do
    output = `tmt help history`
    expected_output = <<-OUT
Usage:
  tmt history ticker

Options:
  -h, [--help], [--no-help]  # Display usage information
      [--ytd], [--no-ytd]    # Only display Year-to-Date history
  -y, [--year=N]             # Display history for given year
  -n, [--normalize=N]        # Normalize contracts to value

Display trade history for ticker, -hi ticker [--history ticker] [--ytd --year=2021 -y=2021 -n=1]
    OUT

    expect(output).to include(expected_output)
  end
end
