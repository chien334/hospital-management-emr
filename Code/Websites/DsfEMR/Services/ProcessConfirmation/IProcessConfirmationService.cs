using DsfEMR.DalLayer;
using DsfEMR.Security;
using DsfEMR.Services.ProcessConfirmation.DTO;

namespace DsfEMR.Services.ProcessConfirmation
{
    public interface IProcessConfirmationService
    {
        object ConfirmProcess(ProcessConfirmationUserCredentials_DTO processConfirmationUserCredentials);
    }
}
