require 'sqlite3'
require 'bloc_record/schema'

module Persistence

  def self.included(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    unless self.id
       self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
       BlocRecord::Utility.reload_obj(self)
       return true
     end
     fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

     self.class.connection.execute <<-SQL
       UPDATE #{self.class.table}
       SET #{fields}
       WHERE id = #{self.id};
     SQL

     true
   end

   def update_attribute(attribute, value)
     self.class.update(self.id, { attribute => value })
   end

   def update_attribute(updates)
     self.class.update(self.id, updates)
   end

   def destroy
     self.class.destroy(self.id)
   end

  module ClassMethods
    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(ids, updates)
     if updates.is_a?(Array)
         0.upto (ids.length-1) do |i|
           update(ids[i], updates[i])
         end

       true
      else
          updates = BlocRecord::Utility.convert_keys(updates)
          updates.delete "id"
          updates_array = updates.map { |key, value | "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}

          if ids.class == Fixnum
            where_clause = "WHERE id = #{ids};"
          elsif ids.class == Array
            where_clause = ids.empty? ? "," : "WHERE id IN (#{ids.join(",")});"
          else
            where_clause = ";"
          end

          connection.execute <<-SQL
            UPDATE #{table}
            SET #{updates_array * ","} #{where_clause}
          SQL

          true
      end
    end

    def method_missing(method, *args, &block)
      if method.include? "update"
        m = method[method.index("_")+1..-1]
      end
      update_attribute(m, arg[0])
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end

        connection.execute <<-SQL
          DELETE FROM #{table} #{where_clause}
        SQL

        true
    end

    def destroy_all(conditions_hash=nil)
      if conditions_hash && !conditions_hash.empty?

        case condition_hash
        when Hash
          conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
          conditions = conditions_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
        when String
          conditions = conditions_hash
        when Array
          conditions = conditions_has.join(",")
        end

        connections.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions}
        SQL
       else
        connection.execute <<-SQL
          DELETE FROM #{table}
        SQL

      true
    end
  end
end
