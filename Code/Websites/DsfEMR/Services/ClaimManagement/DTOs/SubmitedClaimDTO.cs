using DsfEMR.ServerModel.ClaimManagementModels;
using System.Collections.Generic;

namespace DsfEMR.Services.ClaimManagement.DTOs
{
    public class SubmitedClaimDTO
    {
        public InsuranceClaim claim { get; set; }
        public List<UploadedFileDTO> files { get; set; }
    }
}
