RSpec.describe "`tmt open` command", type: :cli do
  it "executes `tmt help open` command successfully" do
    output = `tmt help open`
    expected_output = <<-OUT
Usage:
  tmt open

Options:
  -h, [--help], [--no-help]  # Display usage information

Open a new trade, -o [--new | -n]
    OUT

    expect(output).to include(expected_output)
  end
end
