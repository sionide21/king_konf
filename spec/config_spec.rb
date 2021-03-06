require "king_konf"

describe KingKonf::Config do
  let(:config_class) {
    Class.new(KingKonf::Config) do
      env_prefix :test

      string :greeting, required: true

      desc "pitch level"
      integer :level, default: 0

      desc "whether greeting is enabled"
      boolean :enabled, default: false

      boolean :awesome, default: true

      list :phrases, sep: ";", items: :string

      float :happiness, default: 1.0
    end
  }

  let(:config) { config_class.new }

  it "allows adding a description to variables" do
    expect(config_class.variable(:level).description).to eq "pitch level"
    expect(config_class.variable(:enabled).description).to eq "whether greeting is enabled"
    expect(config_class.variable(:phrases).description).to eq nil
  end

  describe "#validate!" do
    it "raises ConfigError if a required variable is missing" do
      expect {
        config.validate!
      }.to raise_exception(KingKonf::ConfigError, "required variable `greeting` is not defined")
    end
  end

  describe "#decode" do
    it "allows decoding strings into the variable's type" do
      config.decode(:level, "99")

      expect(config.level).to eq 99
    end

    it "raises ConfigError if the value cannot be decoded" do
      expect {
        config.decode(:level, "XXX")
      }.to raise_exception(KingKonf::ConfigError, '"XXX" is not an integer')
    end
  end

  describe "object API" do
    it "allows defining string variables" do
      expect(config.greeting).to eq nil

      config.greeting = "hello!"

      expect(config.greeting).to eq "hello!"

      expect {
        config.greeting = 42
      }.to raise_exception(KingKonf::ConfigError, "invalid value 42 for variable `greeting`, expected string")
    end

    it "allows defining integer variables" do
      expect(config.level).to eq 0

      config.level = 99

      expect(config.level).to eq 99

      expect {
        config.level = "yolo"
      }.to raise_exception(KingKonf::ConfigError, 'invalid value "yolo" for variable `level`, expected integer')
    end

    it "allows defining float variables" do
      expect(config.happiness).to eq 1.0

      config.happiness = 0.5

      expect(config.happiness).to eq 0.5

      # Setting an integer is okay:
      config.happiness = 0

      expect {
        config.happiness = "yolo"
      }.to raise_exception(KingKonf::ConfigError, 'invalid value "yolo" for variable `happiness`, expected float')
    end

    it "allows defining boolean variables" do
      expect(config.enabled).to eq false

      config.enabled = true

      expect(config.enabled).to eq true
      expect(config.enabled?).to eq true

      expect {
        config.enabled = "yolo"
      }.to raise_exception(KingKonf::ConfigError, 'invalid value "yolo" for variable `enabled`, expected boolean')
    end

    it "allows setting boolean variables to false" do
      expect(config.awesome).to eq true

      config.awesome = false

      expect(config.awesome).to eq false
      expect(config.awesome?).to eq false
    end

    it "allows setting variables to nil" do
      config.greeting = "hello"
      config.greeting = nil

      expect(config.greeting).to eq nil
    end
  end

  describe "environment variable API" do
    it "allows setting variables through the ENV" do
      env = {
        "TEST_GREETING" => "hello",
        "TEST_LEVEL" => "42",
        "TEST_ENABLED" => "true",
        "TEST_PHRASES" => "hello, world!;goodbye!;yolo!",
      }

      config = config_class.new(env: env)

      expect(config.greeting).to eq "hello"
      expect(config.level).to eq 42
      expect(config.enabled).to eq true
      expect(config.phrases).to eq ["hello, world!", "goodbye!", "yolo!"]
    end

    it "raises ConfigError if an unknown variable is passed in the ENV" do
      env = {
        "TEST_MISSING" => "hello",
      }

      expect {
        config_class.new(env: env)
      }.to raise_exception(KingKonf::ConfigError, "unknown environment variable TEST_MISSING")
    end
  end
end
