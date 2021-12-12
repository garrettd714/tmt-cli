RSpec.describe "`tmt summary` command", type: :cli do
  it "executes `tmt help summary` command successfully" do
    output = `tmt help summary`
    expected_output = <<-OUT
Usage:
  tmt summary

Options:
  -h, [--help], [--no-help]  # Display usage information
      [--ytd], [--no-ytd]    # Only display Year-to-Date summary
  -y, [--year=N]             # Display summary for given year

Options portfolio summary, -s [--ytd --year=2021 -y=2021]
    OUT

    expect(output).to include(expected_output)
  end
end
