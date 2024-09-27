defmodule Util do
	def db_read(path) do
		_data = case (File.read(path)) do
						 {:ok, contents} -> :erlang.binary_to_term(contents)
						 _ -> nil
					 end
	end
end
