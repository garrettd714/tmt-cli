# frozen_string_literal: true

RSpec.describe "`tmt close` command", type: :cli do
  it "executes `tmt help close` command successfully" do
    output = `tmt help close`
    expected_output = <<-OUT
Usage:
  tmt close id fill fees

Options:
  -h, [--help], [--no-help]  # Display usage information

Close the position, -c id fill fees [--close id fill fees]
    OUT

    expect(output).to include(expected_output)
  end
end
