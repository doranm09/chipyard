package chipyard.fpga.zcu102

import org.chipsalliance.cde.config.Config
import freechips.rocketchip.subsystem._
import freechips.rocketchip.tile._


class WithoutCompressedRocket extends Config((site, here, up) => {
  case TilesLocated(InSubsystem) => up(TilesLocated(InSubsystem), site).map {
    case r: RocketTileParams => r.copy(core = r.core.copy(useCompressed = false))
    case other => other
  }
})
