require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'

class MassObject
  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end
end

class SQLObject < MassObject

  attr_accessor :attributes

  def self.columns
    column_names = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{table_name}
      LIMIT 1
    SQL

    column_names.map! { |col| col.to_sym }

    column_names.each do |column_name|
      define_method(column_name) do
        attributes[column_name]
      end

      define_method("#{column_name}=") do |arg|
        attributes[column_name] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.pluralize.underscore
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(all)
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT DISTINCT
        *
      FROM
        #{self.table_name}
      WHERE
       #{self.table_name}.id = ?
    SQL

    self.parse_all(results).first

  end

  def attributes
    @attributes = Hash.new if @attributes.nil?
    @attributes
  end

  def insert
    col_names = self.class.columns.map(&:to_s).join(", ")
    question_marks = (["?"] * self.class.columns.count).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{ self.class.table_name } (#{ col_names })
      VALUES
         (#{ question_marks })
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params_hash = {})
    params_hash.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      else
        self.attributes[attr_name.to_sym] = value
      end
    end
  end

  def save
    if id.nil?
      insert
    else 
      update
    end
  end

  def update
    set_line = self.class.columns.map {|attr_name| "#{ attr_name } = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{ self.class.table_name }
      SET
        #{ set_line }
      WHERE
         #{ self.class.table_name }.id = ?
    SQL
  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end
end