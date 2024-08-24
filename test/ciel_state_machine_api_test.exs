defmodule CielStateMachineApiTest do
	use ExUnit.Case, async: true
	use Plug.Test
	test "ping returns" do
		conn = conn(:get, "/ping")
		conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
		assert conn.state == :sent
		assert conn.status == 200
		assert conn.resp_body == "pong!"
	end
	test "supply post test" do
		conn = conn(:post, "/supply",%{supply_idx: 2, vehicle_plate_num: "54가 1111"} )
		conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
		# TODO wait for add_entry process(handle_cast), need to change to handle_call??????
		# comment this will trigger test failure
		Process.sleep(100)
		# handle call
		entries = CielStateMachine.Server.entries(2)
		#IO.puts "\n ********** after add_entry, entries = #{inspect(entries)}"
		assert conn.status == 200
		assert conn.resp_body == "OK"
		assert Enum.empty?(entries) == false
	end
	test "supply post test wrong payload" do
		conn = conn(:post, "/supply", "hello world" )
		conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
		# IO.puts "resp body = #{inspect(conn)}"
		assert conn.status == 422
	end
end
