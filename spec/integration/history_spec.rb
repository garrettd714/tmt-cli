RSpec.describe "`tmt history` command", type: :cli do
  it "executes `tmt help history` command successfully" do
    output = `tmt help history`
    expected_output = <<-OUT
Usage:
  tmt history TICKER

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
