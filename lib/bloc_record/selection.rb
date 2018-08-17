require 'sqlite3'

 module Selection

   COLUMNS = [:name, :phone_number]


   def find(*ids)
    if ids.kind_of? Integer && ids > 0
      if ids.length == 1
        find_one(ids.first)
      else
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          WHERE id IN (#{ids.join(",")});
        SQL
        rows_to_array(rows)
      end
     else
       puts "The id you entered is invalid"
     end
    end

   def find_one(id)
     if ids.kind_of? Integer && ids > 0
       row = connection.get_first_row <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         WHERE id = #{id};
        SQL

         init_object_from_row(row)

      else
        puts "The id you entered is invalid"
      end
   end

   def find_by(attribute, value)
     rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
      SQL

      if rows_to_array(rows) == []
        puts "Incorrect entry"
      else
        rows_to_array(rows)
      end
   end

   def method_missing(method, *args, &block)
     if COLUMNS != nil
       COLUMNS.find do |column|
         puts "This is the column: #{column}"
         match = column
         if match  === method
           puts "This method exists"
           find_by(match, args[0])
         end
       end
      else
        super
        puts "There's no method called #{method}"
      end
    end

    def find_each(start: 2000, batch_size: 2000)
      rows = connection.execute <<-SQL
        SELECT#{columns.join ","} FROM #{table}
        LIMIT #{batch_size}
      SQL

      for row in rows_to_array(row)
        yield(row)
      end
    end

    def find_in_batches(start: 4000, batch_size: 2000)
      rows = connection.execute <<-SQL
        SELECT #{COLUMNS.join ","} FROM #{table}
        LIMIT #{batch_size}
      SQL

      yeild(rows_to_array(rows))
    end
   end

   def take(num=1)
     if num > 1
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         ORDER BY random()
         LIMIT #{num}
       SQL

       rows_to_array(rows)
      else
        take_one
      end
   end

   def take_one
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY random()
       LIMIT 1;
      SQL

      init_object_from_row(row)
   end

   def first
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY id ASC LIMIT 1;
     SQL

     init_object_from_row(row)
   end

   def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
   end

   def all
     rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
     SQL

     rows_to_array(rows)
   end

   def where(*args)
     if args.count > 1
       expression = args.shift
       params = args
     else
       case args.first
       when String
         expression = args.first
       when Hash
         expression_hash = BlocRecord::Utility.convert_keys(args.first)
         expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utiliy.sql_strings(value)}"}.join(" and ")
       end
     end


   sql = <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    WHERE #{expression};
   SQL

   rows = connection.execute(sql, params)
   rows_to_array(rows)
  end

  def order(*args)
    ordered = []
     args.each do |arg|
       case arg
       when String
         ordered << arg
       when Symbol
         ordered << arg.to_s
       when Hash
         ordered << arg.map{|key, value| "#{key} #{value}"}
       end
     end
     order = ordered.join(",")

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order}
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL

      when Hash
         key = args.first.keys.first
         value = args.first[key]
         rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{key} ON #{key}.#{table}.id = #{table}.id
          INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id;
        SQL
       end
      end

      rows_to_array(rows)
    end


   private
   def init_object_from_row(row)
     if row
       data = Hash[columns.zip(row)]
       new(data)
     end
   end

   def rows_to_array(rows)
     rows.map { |row| new(Hash[columns.zip(row)]) }
   end
