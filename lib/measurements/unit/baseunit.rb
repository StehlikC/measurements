module Measurements
    module Unit        
        module BaseUnit
                        
            # @attribute [rw]
            # The quantity of a unit
            attr_accessor :quantity
            
            def initialize(quantity, type = nil)
                @quantity = quantity.to_f
                
                if !type.nil?
                    self.type = type
                else
                    @type = type
                end
            end
            
            # Set the unit type of a unit manually. A type can only be set for units with the
            #   unit type of "neutral", any other unit type will raise and error.
            # @attribute [w]
            # @param [String] type the type of unit the unit should be.
            def type=(type)
                if self.unit_type.eql? "neutral"
                    @type = type
                else
                    raise Measurements::Exception::InvalidTypeSettingError, "Types can only be set on neutral units."
                end
            end
            
            # @attribute [r]
            # The manual set unit_type
            def type
                @type
            end
            
            # @attribute [r]
            # The type of the editable type of the unit. This is
            #   used to limit the conversions from fluid to solid
            def unit
                self.class.name.split('::').last.downcase.to_s
            end
            
            # @attribute [r]
            # The system of measurement of the unit
            def unit_system
                eval(self.class.to_s + "::UNIT_SYSTEM")
            end
            
            # @attribute [r]
            # The class type of the unit, such as Liquid or Neutral
            def unit_type
                eval(self.class.to_s + "::UNIT_TYPE")
            end
            
            # @attribute [r]
            # The abbreviation of the unit depending on the locale
            def unit_abbr
                if @quantity <= 1
                    Measurements::Unit::ABBREVIATIONS["abbreviations"][Measurements::LOCALE]["singular"][self.unit]
                else
                    Measurements::Unit::ABBREVIATIONS["abbreviations"][Measurements::LOCALE]["plural"][self.unit]
                end
            end
            
            # When you look at a unit object the quantity will be displayed.
            #   It seemed like a nicer way to display the unit, kind of like a [Float]
            def inspect
                @quantity
            end
            
            # Convert the current unit into a new unit of the type given
            # @param [Symbol] type the type of unit to convert to
            # @return [BaseUnit] the new unit, it will be a subclass of [BaseUnit].
            # @raise [InvalidConversionError] gets raised if the type of conversion is not valid.
            def convert_to(type)
                type = type.to_s
                
                if !validate_system(type)
                    raise Measurements::Exception::InvalidConversionError, "A conversion must be from the same system type."
                end
                
                if validate_conversion(type)
                    base = convert_to_base(self, type)
                    return convert_to_type(base, type)
                else
                    raise Measurements::Exception::InvalidConversionError, "A conversion must be from the same type or neutral."
                end
            end
            
            protected
            
            # Get the unit type of the class passed in as a string
            # @param [String] type the class name as a string
            # @return [String] the unit type of the class that was passed in.
            def unit_type_from_type(type)
                eval("Measurements::Unit::" + type.capitalize + "::UNIT_TYPE")
            end
            
            # Get the unit system of the class passed in as a string
            # @param [String] type the class name as a string
            # @return [String] the unit system of the class that was passed in.
            def unit_system_from_type(type)
                eval("Measurements::Unit::" + type.capitalize + "::UNIT_SYSTEM")
            end
            
            # Validate if the systems of the converting units match. A conversion will only
            #   be allowed if the two units are from the same unit system.
            # @param [String] to the unit type to convert to
            # @return [Boolean] true if the conversion is valid.
            # @raise [NoUnitError] gets raised if the from or to units could not be found
            def validate_system(to)
                from = self.unit
                
                begin
                    from = unit_system_from_type from
                    to = unit_system_from_type to
                rescue
                    raise Measurements::Exception::NoUnitError, "The unit you're trying to convert to does not exist."
                end
                
                from.eql? to
            end

            # Validate if a conversion will be valid. A conversion will be valid if one
            #   of the units types are neutral or if the unit types are the same.
            # @param [String] to the unit type to convert to
            # @return [Boolean] True if the conversion is valid.
            # @raise [NoUnitError] gets raised if the from or to units could not be found
            def validate_conversion(to)
                from = self.unit
                
                begin
                    from = unit_type_from_type from
                    to = unit_type_from_type to
                rescue
                    raise Measurements::Exception::NoUnitError, "The unit you're trying to convert to does not exist."
                end
                
                (from.eql?("neutral") || to.eql?("neutral") || from.eql?(to)) && (self.type.nil? || self.type.eql?("neutral") || self.type.eql?(to))
            end
            
            # Convert the current unit into the base unit for its type.
            # @param [BaseUnit] current the unit to be converted, it should be a subclass of [BaseUnit]
            # @return [BaseUnit] the base unit.
            def convert_to_base(current, type = nil)
                if !type.nil?
                    unit_type = unit_type_from_type type
                
                    if !unit_type.eql? "neutral"
                        measurement_list = Measurements::Unit::CONVERSIONS["conversions"][current.unit_system][unit_type]
                    else
                        measurement_list = Measurements::Unit::CONVERSIONS["conversions"][current.unit_system][current.unit_type]
                    end
                else
                    measurement_list = Measurements::Unit::CONVERSIONS["conversions"][current.unit_system][current.unit_type]
                end
                
                quantity_to_mst = measurement_list[current.unit].to_f != 0.0 ? measurement_list[current.unit] : 1.0
                base_type = measurement_list["base"]
                
                eval("Measurements::Unit::" + base_type.capitalize).new(current.quantity / quantity_to_mst, current.type)
            end
            
            # Take the base unit and convert it to the requested type. If the type requested
            #   is the same type as the base, just return the base unit back.
            # @param [BaseUnit] base the base unit to be converted
            # @param [String] type the type of unit the base should be converted to
            # @return [BaseUnit] the new unit, it will be a subclass of [BaseUnit]
            def convert_to_type(base, type)
                if base.unit.eql? type
                    return base
                else
                    measurement_list = Measurements::Unit::CONVERSIONS["conversions"][base.unit_system][base.unit_type]
                    quantity_to_type = measurement_list[type]
                    
                    eval("Measurements::Unit::" + type.capitalize).new(base.quantity * quantity_to_type, base.type)
                end
            end
            
            def conversion_progression
                if self.type == nil
                    measurement_list = Measurements::Unit::CONVERSIONS["conversions"][self.unit_system][self.unit_type].dup
                else
                    measurement_list = Measurements::Unit::CONVERSIONS["conversions"][self.unit_system][self.type].dup
                end
                
                measurement_list.delete("base")
                measurement_list.sort{|x, y| x.last <=> y.last}.map{|x| x.first}
            end
        end
    end
end