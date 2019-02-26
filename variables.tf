variable "loc" {
    description = "Default Azure region"
    default     =   "WestEurope"
}

variable "tags" {
    description = "tags to apply to resources"
    default     = {
        source  = "citadel"
        env     = "training"
    }
}