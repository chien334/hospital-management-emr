using AutoMapper;
using DsfEMR.ServerModel;
using DsfEMR.Services.Pharmacy.DTOs.PurchaseOrder;

namespace DsfEMR.Services.Pharmacy.Mapper.PurchaseOrder
{
    public class PurchaseOrderMappingProfile : Profile
    {
        public PurchaseOrderMappingProfile()
        {
            CreateMap<PurchaseOrder_DTO, PHRMPurchaseOrderModel>().ForMember(dest => dest.PHRMPurchaseOrderItems, act => act.Ignore());
            CreateMap<PurchaseOrderItems_DTO, PHRMPurchaseOrderItemsModel>();
        }
    }
}
