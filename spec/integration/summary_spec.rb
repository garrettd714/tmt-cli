RSpec.describe "`tmt summary` command", type: :cli do
  it "executes `tmt help summary` command successfully" do
    output = `tmt help summary`
    expected_output = <<-OUT
Usage:
  tmt summary

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
