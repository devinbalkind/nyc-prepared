puts '===> Setting up test super admin...'
admin3 = Admin.create! :name => 'Devin Balkind',
                     :email => 'devin@sarapis.org',
                     :password => 'sarapis123',
                     :password_confirmation => 'sarapis123'
admin3.confirm!
