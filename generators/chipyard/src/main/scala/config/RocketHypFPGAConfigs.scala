package chipyard

import org.chipsalliance.cde.config.{Config}  // Updated import for new Chipyard versions
import freechips.rocketchip.subsystem._
import chipyard.config._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.rocket._
import freechips.rocketchip.tile._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.util._
import freechips.rocketchip.prci._  // Required for crossing parameters
import freechips.rocketchip.rocket.{WithNBigCores, WithNMedCores, WithNSmallCores, WithRV32, WithFP16, WithHypervisor, With1TinyCore, WithScratchpadsOnly, WithCloneRocketTiles, WithB}


class RocketHypConfigzcu104 extends RocketHypZCU(4)

class RocketHypZCU(numHarts: Int) extends Config(
  // new WithHarnessClockInstantiator ++
  new Config((site, here, up) => {
      case ExtMem => Some(MemoryPortParams(MasterPortParams(
                  base = 0x40000000L,
                  size = 0x40000000L, // 1GB external memory
                  beatBytes = site(MemoryBusKey).beatBytes,
                  idBits = 4), 1))
      case ExtBus => Some(MasterPortParams(
                  base = 0xFF000000L,
                  size = 0x01000000L, // 16MB external bus
                  beatBytes = site(MemoryBusKey).beatBytes,
                  idBits = 4))
  }) ++
  new freechips.rocketchip.subsystem.WithNExtTopInterrupts(2) ++  // 2 external interrupts
  new freechips.rocketchip.subsystem.WithBootROMFile(s"./bootromFPGA/bootrom_zynqmp.img") ++
  new RocketFPGAConfig(numHarts)
)

class RocketFPGAConfig(numHarts: Int) extends Config(
  // new Config((site, here, up)=> {
  //   case RocketTilesKey => up(RocketTilesKey, site) map { r =>
  //       r.copy(core = r.core.copy(haveCFlush = true)) 
  //   }
  // }) ++
  // new freechips.rocketchip.subsystem.WithHyp ++
  // new freechips.rocketchip.subsystem.WithNBigCores(numHarts) ++
  // new Config((site, up, here) => {
  //   case DebugModuleKey => None
  // }) ++
  new chipyard.config.WithL2TLBs(1024) ++                        // use L2 TLBs
  new freechips.rocketchip.subsystem.WithNoSlavePort ++          // no top-level MMIO slave port (overrides default set in rocketchip)
  // new freechips.rocketchip.subsystem.WithInclusiveCache ++       // use Sifive L2 cache
  new freechips.rocketchip.subsystem.WithInclusiveCache ++  
  new freechips.rocketchip.subsystem.WithCoherentBusTopology ++  // hierarchical buses including mbus+l2
  new freechips.rocketchip.system.BaseConfig
)