defmodule CielStateMachine.MixProject do
  use Mix.Project

  def project do
    [
      app: :ciel_state_machine,
			aliases: aliases(),
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :observer, :wx, :runtime_tools],
      mod: {CielStateMachine.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
			{:poolboy, "~> 1.5"},
			{:plug_cowboy, "~> 2.6"},
			{:poison, "~> 4.0.1"},
			{:req, "~> 0.5.6"},
			{:ex_doc, "~> 0.31", only: :dev, runtime: false},
			{:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},
    ]
  end
	def aliases do
		[
			generate_docs: [
				"docs",
				"inch"
			]
		]
	end

end
