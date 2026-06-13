using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DsfEMR.ServerModel.InventoryModels
{
    public class Vertical
    {
        [Key]
        public int VerticalId { get; set; }
        public string VerticalName { get; set; }
    }
}
