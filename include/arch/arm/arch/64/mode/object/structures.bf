--
-- Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
--
-- SPDX-License-Identifier: GPL-2.0-only
--

#include <config.h>
-- Default base size: uint64_t
#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
base 64(48,0)
#else
base 64(48,1)
#endif
#define BF_CANONICAL_RANGE 48

-- Including the common structures_64.bf is neccessary because
-- we need the structures to be visible here when building
-- the capType
#include <object/structures_64.bf>
 
---- ARM-specific caps

block frame_cap {
    field capFMappedASID             16
    field_high capFBasePtr           48

    field capType                    5
    field capFSize                   2
    field_high capFMappedAddress     48
    field capFVMRights               2
    field capFIsDevice               1
    padding                          6
}

-- Forth-level page table
block page_table_cap {
    field capPTMappedASID            16
    field_high capPTBasePtr          48

    field capType                    5
    padding                          10
    field capPTIsMapped              1
    field_high capPTMappedAddress    28
    padding                          20
}

-- Third-level page table (page directory)
block page_directory_cap {
    field capPDMappedASID            16
    field_high capPDBasePtr          48

    field capType                    5
    padding                          10
    field capPDIsMapped              1
    field_high capPDMappedAddress    19
    padding                          29
}

-- Second-level page table (page upper directory)
block page_upper_directory_cap {
    field capPUDMappedASID           16
    field_high capPUDBasePtr         48

    field capType                    5
    field capPUDIsMapped             1
    field_high capPUDMappedAddress   10
    padding                          48
}

-- First-level page table (page global directory)
block page_global_directory_cap {
    field capPGDMappedASID           16
    field_high capPGDBasePtr         48

    field capType                    5
    field capPGDIsMapped             1
    padding                          58
}

-- Cap to the table of 2^7 ASID pools
block asid_control_cap {
    padding                          64

    field capType                    5
    padding                          59
}

-- Cap to a pool of 2^9 ASIDs
block asid_pool_cap {
    padding                         64

    field capType                   5
    field capASIDBase               16
    padding                         6
    field_high capASIDPool          37
}

#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
block vcpu_cap {
    padding                         64

    field      capType              5
    field_high capVCPUPtr           48
    padding                         11
}
#endif

-- NB: odd numbers are arch caps (see isArchCap())
tagged_union cap capType {
    -- 5-bit tag caps
    tag null_cap                    0
    tag untyped_cap                 2
    tag endpoint_cap                4
    tag notification_cap            6
    tag reply_cap                   8
    tag cnode_cap                   10
    tag thread_cap                  12
    tag irq_control_cap             14
    tag irq_handler_cap             16
    tag zombie_cap                  18
    tag domain_cap                  20
#ifdef CONFIG_KERNEL_MCS
    tag sched_context_cap           22
    tag sched_control_cap           24
#endif

    -- 5-bit tag arch caps
    tag frame_cap                   1
    tag page_table_cap              3
    tag page_directory_cap          5
    tag page_upper_directory_cap    7
    tag page_global_directory_cap   9
    tag asid_control_cap            11
    tag asid_pool_cap               13
#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
    tag vcpu_cap                    15
#endif
}

---- Arch-independent object types

block VMFault {
    field address                   64
    field FSR                       32
    field instructionFault          1
    padding                         27
    field seL4_FaultType            4
}

#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
block VGICMaintenance {
    padding          64

    field idx        6
    field idxValid   1
    padding         25
    padding         28
    field seL4_FaultType  4
}

block VCPUFault {
    padding         64
    field hsr       32
    padding         28
    field seL4_FaultType  4
}

block VPPIEvent {
    field irq_w     64
    padding         32
    padding         28
    field seL4_FaultType  4
}
#endif

-- VM attributes

block vm_attributes {
    padding                         61
    field armExecuteNever           1
    field armParityEnabled          1
    field armPageCacheable          1
}

---- ARM-specific object types

-- PGDE, PUDE, PDEs and PTEs, assuming 48-bit physical address
base 64(48,0)

-- hw_asids are required in hyp mode
block pgde_invalid {
    field stored_hw_asid            8
    field stored_asid_valid         1
    padding                         53
    field pgde_type                 2
}

block pgde_pud {
    padding                         16
    field_high pud_base_address     36
    padding                         10
    field pgde_type                 2 -- must be 0b11
}

tagged_union pgde pgde_type {
    tag pgde_invalid                0
    tag pgde_pud                    3
}

block pude_invalid {
    field stored_hw_asid            8
    field stored_asid_valid         1
    padding                         53
    field pude_type                 2
}

block pude_1g {
    padding                         9
    field UXN                       1
    padding                         6
    field_high page_base_address    18
    padding                         18
    field nG                        1
    field AF                        1
    field SH                        2
    field AP                        2
#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
    field AttrIndx                  4
#else
    padding                         1
    field AttrIndx                  3
#endif
    field pude_type                 2
}

block pude_pd {
    padding                         16
    field_high pd_base_address      36
    padding                         10
    field pude_type                 2
}

tagged_union pude pude_type {
    tag pude_invalid                0
    tag pude_1g                     1
    tag pude_pd                     3
}

block pde_large {
    padding                         9
    field UXN                       1
    padding                         6
    field_high page_base_address    27
    padding                         9
    field nG                        1
    field AF                        1
    field SH                        2
    field AP                        2
#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
    field AttrIndx                  4
#else
    padding                         1
    field AttrIndx                  3
#endif
    field pde_type                  2
}

block pde_small {
    padding                         16
    field_high pt_base_address      36
    padding                         10
    field pde_type                  2
}

tagged_union pde pde_type {
    tag pde_large                   1
    tag pde_small                   3
}

block pte {
    padding                         9
    field UXN                       1
    padding                         6
    field_high page_base_address    36
    field nG                        1
    field AF                        1
    field SH                        2
    field AP                        2
#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
    field AttrIndx                  4
#else
    padding                         1
    field AttrIndx                  3
#endif
    field reserved                  2 -- must be 0b11
}

block ttbr {
    field asid                      16
    field_high base_address         48
}

#include <sel4/arch/shared_types.bf>
