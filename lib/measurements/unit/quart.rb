module Measurements
    module Unit
        
        # The implementation of a quart. A quart is a fluid unit that belongs to the cooking unit 
        #   system.
        class Quart
            include BaseUnit
            
            # Type for the Cup unit
            UNIT_TYPE = Measurements::Type::FLUID
            
            # System type for the Cup unit
            UNIT_SYSTEM = Measurements::System::COOK
        end
        
    end
end