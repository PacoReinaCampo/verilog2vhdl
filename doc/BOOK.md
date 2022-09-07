# verilog2vhdl
## QueenField

![QueenField](../icon.jpg)

# 1. INTRODUCTION

A Hardware Description Language (HDL) is a specialized computer language used to describe the structure and behavior of digital logic circuits. It allows for the synthesis of a HDL into a netlist, which can then be synthesized, placed and routed to produce the set of masks used to create an integrated circuit.

# 2. PROJECTS

```
.1. module_definitions
.1.1. module_items
.1.1.1. data_type_declarations
.1.1.2. module_instances
.1.1.3. primitive_instances
.1.1.4. generate_blocks
.1.1.5. procedural_blocks
.1.1.6. continuous_assignments
.1.1.7. task_definitions
.1.1.8. function_definitions
.1.1.9. specify_blocks
.1.2. port_declarations
.2. data_type_declarations
.2.1. net_data_types
.2.2. variable_data_types
.2.3. other_data_types
.2.4. vector_bit_selects_and_part_selects
.2.5. array_selects
.2.6. reading_and_writing_arrays
.3. module_instances
.4. primitive_instances
.5. generate_blocks
.6. procedural_blocks
.6.1. procedural_time_controls
.6.2. sensitivity_lists
.6.3. procedural_assignment_statements (=continuous_assignments)
.6.4. procedural_programming_statements
.6.4.1. if_part
.6.4.2. case_part
.6.4.3. casex_part
.6.4.4. casez_part
.6.4.5. for_part
.6.4.6. while_part
.6.4.7. repeat_part
.6.4.8. forever_part
.6.4.9. disable_part
.7. continuous_assignments
.8. operators
.9. task_definitions
.10. function_definitions
.11. specify_blocks
.11.1. pin_to_pin_path_delays
.11.2. path_pulse_detection
.11.3. timing_constraint_checks
.12. user_defined_primitives
.13. common_system_tasks_and_functions
.14. common_compiler_directives
.15. configurations
.16. synthesis_supported_constructs
```

# 3. WORKFLOW

```
source install.sh

cd test
source test-msp430.sh
source test-riscv.sh
```
