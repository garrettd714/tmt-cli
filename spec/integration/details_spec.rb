RSpec.describe "`tmt details` command", type: :cli do
  it "executes `tmt help details` command successfully" do
    output = `tmt help details`
    expected_output = <<-OUT
Usage:
  tmt details id

Options:
  -h, [--help], [--no-help]        # Display the details of a position
  -r, [--refresh], [--no-refresh]  # Refresh the details of a position

Position detailed view, -d id [--show id | -s id]
    OUT

    expect(output).to include(expected_output)
  end
end
