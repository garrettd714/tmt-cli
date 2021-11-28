require 'tmt/commands/details'

RSpec.describe Tmt::Commands::Details do
  xit "executes `details` command successfully" do
    output = StringIO.new
    id = nil
    options = {}
    command = Tmt::Commands::Details.new(id, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
