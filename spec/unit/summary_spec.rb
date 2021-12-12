require 'tmt/commands/summary'

RSpec.describe Tmt::Commands::Summary do
  it "executes `summary` command successfully" do
    output = StringIO.new
    options = {}
    command = Tmt::Commands::Summary.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
