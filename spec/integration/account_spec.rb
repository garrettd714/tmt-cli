RSpec.describe "`tmt account` command", type: :cli do
  it "executes `tmt help account` command successfully" do
    output = `tmt help account`
    expected_output = <<-OUT
Usage:
  tmt account token

Options:
  -h, [--help], [--no-help]      # Display usage information
      [--ytd], [--no-ytd]        # Only display Year-to-Date history
  -y, [--year=N]                 # Display history for given year
  -d, [--detail], [--no-detail]  # Display table of ticker details

Account summary, -a token [--ytd --year=2021 -y=2021]
    OUT

    expect(output).to include(expected_output)
  end
end
