require 'tmt/commands/open'

RSpec.describe Tmt::Commands::Open do
  xit "executes `open` command successfully" do
    output = StringIO.new
    options = {}
    command = Tmt::Commands::Open.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
