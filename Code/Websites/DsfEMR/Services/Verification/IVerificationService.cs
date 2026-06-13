using DsfEMR.ServerModel;
using System.Collections.Generic;

namespace DsfEMR.Services
{
    public interface IVerificationService
    {
        int CreateVerification(int EmployeeId,int CurrentVerificationLevel,int CurrentVerificationLevelCount, int MaxVerificationLevel, string VerificationStatus,string VerificationRemarks,int? ParentVerificationId);
        List<VerificationViewModel> GetVerificationViewModel(int VerificationId);
        int UpdateVerifcation(int VerificationId, int EmployeeId, string VerificationStatus);
    }
}