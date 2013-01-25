== Bokför provisionen för en beställning i Fortnox

Ordern behöver svara på Order#line_items som i sin tur har en preview_url och ha attribute 

* voucher_id
* voucher_last_error

Och svara på följande metoder

* id
* paid_at
* bookkeep_amount

I Gemfilen lägg till

```ruby
gem "fortnox", :git => 'git://github.com/jnstq/fortnox.git'
gem "bookkeep", :git => 'git://github.com/jnstq/bookkeep.git'
```


I applicaton.yml sätt env variablerna för hur beställningen ska bokföras. Titta i bookkeep.rb för att se vilka inställningar som finns.

    fortnox_token: "..."
    fortnox_database: "..."
    bookeep_voucher_description: "Provision ..."
    bookeep_account_in: "1060"
    bookeep_account_system: "3043"
    
Lägg till ett scope på ordern för att hitta orders som ännu inte är bokförda än

```ruby
scope :unbooked, lambda { paid.where('id > ?', 7642).where(:voucher_id => nil) }
```

I schedule.rb lägg till ett jobb som körs minst en gång om dagen

```ruby
every 1.day, :at => '05:00' do
  runner "Bookkeep.process(Order.unbooked)"
end
```
