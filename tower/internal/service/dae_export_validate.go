package service

import (
	"context"
	"strings"

	"github.com/kenzok8/tower/internal/model"
)

// honkIncludeBlock is what a honk export references instead of its own global
// section.
const honkIncludeBlock = "include {\n    system.dae\n}"

// honkValidationGlobal stands in for honk's /etc/honk/system.dae while the
// routing table is validated.
const honkValidationGlobal = "global {\n    tproxy_port: 12345\n    lan_interface: br-lan\n    wan_interface: auto\n}"

// validateDAEExport proves a dae or honk export against the device DAT files.
//
// honk only warns about an unknown geosite/geoip code ("rule will never match"),
// so a typo would ship a rule that silently never matches. Both cores read the
// same /usr/share/v2ray DAT files, and dae validate fails loudly on an unknown
// code, so the honk config is validated with its include block rewritten.
func (s *Service) validateDAEExport(target model.ClientTarget, content string) error {
	switch target {
	case model.ClientDAE:
		return s.daeValidate(context.Background(), content)
	case model.ClientHonk:
		return s.daeValidate(context.Background(), honkValidationConfig(content))
	default:
		return nil
	}
}

// honkValidationConfig swaps honk's include block for a minimal global section so
// dae can parse the rest of the file.
func honkValidationConfig(content string) string {
	if !strings.Contains(content, honkIncludeBlock) {
		return content
	}
	return strings.Replace(content, honkIncludeBlock, honkValidationGlobal, 1)
}
