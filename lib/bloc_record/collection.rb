module BlocRecord
  class Collection < Array

    def update_all(updates)
      ids = self.map(&:id)

      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(num=1)
      if self.any?
        self[0, num]
      else
        false
      end
    end

    def where(hash)
      self.select {|obj| obj.attributes[hash.keys.first] == hash.values.first}
    end

    def not
      self.select {|obj| obj.attributes[hash.keys.first] != hash.values.first}
    end
   end
 end
