require_relative 'db_connection'
require_relative '02_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map {|key| "#{key} = ?"}
     DBConnection.execute(<<-SQL, *attribute_values)
      SELECT
      	*
      FROM
      	
    SQL

  end
end

class SQLObject
  # Mixin Searchable here...
end
