class Dog 

     attr_accessor :id, :name, :breed

     def initialize(id: nil, name:, breed:)
          @id = id
          @name = name
          @breed = breed
     end

     def self.create_table
          sql = <<-SQL
          CREATE TABLE IF NOT EXISTS dogs (
               id INTEGER PRIMARY KEY, 
               name TEXT, 
               breed TEXT
          )
          SQL
          
          DB[:conn].execute(sql)
     end

     def self.drop_table
          sql = "DROP TABLE IF EXISTS dogs"
          DB[:conn].execute(sql)
     end

     def save 
          if self.id
               self.update
          else
               sql = <<-SQL
               INSERT INTO dogs (name, breed)
               VALUES (?, ?)
               SQL
               DB[:conn].execute(sql, self.name, self.breed)
               @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
          end
          self
     end

     # Takes in a hash of attributes and uses metaprogramming to create a new dog object.
     # Then it uses save method to save that dogs to the database. Returns a new dog. 
     def self.create(name:, breed:)
          new_dog = self.new(name: name, breed: breed)
          new_dog.save
     end


     def self.new_from_db(row)
          new_id  = row[0]
          new_name = row[1]
          new_breed = row[2]
          new_dog = self.new(id: new_id, name: new_name, breed: new_breed)
     end

     def self.find_by_id(id)
          sql = <<-SQL
          SELECT *
          FROM dogs 
          WHERE id = ?
          LIMIT 1
          SQL

          DB[:conn].execute(sql, id).map do |row|
               self.new_from_db(row)
          end.first
     end

     def self.find_or_create_by(name:, breed:)
          sql = <<-SQL
          SELECT *
          FROM dogs 
          WHERE name = ?
          AND breed = ?
          SQL

          dog = DB[:conn].execute(sql, name, breed)

          if !dog.empty?
               dog_data = dog[0]
               dog = self.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
          else
               dog = self.create(name: name, breed: breed)
          end 
          dog
     end

     def self.find_by_name(name)
          DB[:conn].execute("SELECT * FROM dogs WHERE name = ?", name).map do |row|
               self.new_from_db(row)
          end.first
     end

     def update
          sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
          DB[:conn].execute(sql, self.name, self.breed, self.id)
     end

end
