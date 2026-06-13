using AutoMapper;
using DsfEMR.ServerModel.BillingModels;

namespace DsfEMR.Controllers.Settings.DTO
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<BillSchemeDTO, BillingSchemeModel>();
        }
    }
}
