module Measurements
    module Unit
        
        # The implementation of a gallon. A gallon is a fluid unit that belongs to the cooking unit 
        #   system.
        class Gallon
            include BaseUnit
            
            # Type for the Cup unit
            UNIT_TYPE = Measurements::Type::FLUID
            
            # System type for the Cup unit
            UNIT_SYSTEM = Measurements::System::COOK
        end
        
    end
end