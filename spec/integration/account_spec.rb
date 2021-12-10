RSpec.describe "`tmt account` command", type: :cli do
  it "executes `tmt help account` command successfully" do
    output = `tmt help account`
    expected_output = <<-OUT
Usage:
  tmt account TICKER

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
