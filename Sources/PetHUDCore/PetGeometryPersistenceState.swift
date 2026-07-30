public struct PetGeometryPersistenceState: Sendable {
    private var persistedGeometry: PetVisualGeometry?

    public init(
        persistedGeometry: PetVisualGeometry? = nil
    ) {
        self.persistedGeometry = persistedGeometry
    }

    public func needsPersistence(
        _ geometry: PetVisualGeometry
    ) -> Bool {
        geometry.source == .shellDerived &&
            geometry != persistedGeometry
    }

    public mutating func recordPersisted(
        _ geometry: PetVisualGeometry
    ) {
        guard geometry.source == .shellDerived else {
            return
        }
        persistedGeometry = geometry
    }
}
