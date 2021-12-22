ActiveRecord::Associations::Preloader.class_eval do

  #patching to ignore nil response from association method (also patched)

  #if there is no association just return nil instead
  def grouped_records(association, records)
    h = {}
    records.each do |record|
      next unless record
      assoc = record.association(association)
      if assoc.nil?
#        puts "here"
      else
        klasses = h[assoc.reflection] ||= {}
        (klasses[assoc.klass] ||= []) << record
      end
    end
    h
  end

end
